# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id                       :bigint           not null, primary key
#  content                  :text(65535)      not null
#  current_version_no       :integer          not null
#  hidden                   :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  author_id                :bigint           not null
#  hidden_cause_decision_id :bigint
#  topic_id                 :bigint           not null
#
# Indexes
#
#  idx_comments_author_id            (author_id)
#  idx_comments_topic_id_created_at  (topic_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (topic_id => topics.id)
#
require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe '.create_with_history!' do
    let(:topic) { create(:topic) }
    let(:author) { create(:user) }
    let(:content) { 'テストコメント内容' }

    context '基本機能' do
      it 'コメントとその履歴を作成し、トピックの総コメント数を増加させる' do
        comment = nil

        expect do
          comment = described_class.create_with_history!(
            topic: topic,
            author: author,
            content: content
          )
        end.to change(described_class, :count).by(1)
          .and change(CommentHistory, :count).by(1)
          .and change { topic.reload.total_comment }.by(1)

        aggregate_failures do
          expect(comment).to be_persisted
          expect(comment.topic).to eq(topic)
          expect(comment.author).to eq(author)
          expect(comment.content).to eq(content)
          expect(comment.current_version_no).to eq(1)

          history = comment.histories.first
          expect(history).to be_persisted
          expect(history.topic).to eq(topic)
          expect(history.author).to eq(author)
          expect(history.content).to eq(content)
          expect(history.version_no).to eq(1)
        end
      end
    end

    context 'トランザクション' do
      it 'コメント履歴の作成に失敗した場合、全体がロールバックされる' do
        allow_any_instance_of(CommentHistory).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(CommentHistory.new))

        expect do
          described_class.create_with_history!(
            topic: topic,
            author: author,
            content: content
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
         .and change(described_class, :count).by(0)
         .and change(CommentHistory, :count).by(0)
         .and change { topic.reload.total_comment }.by(0)
      end

      it 'お題の総コメント数更新に失敗した場合、全体がロールバックされる' do
        allow_any_instance_of(Topic).to receive(:increment_total_comment!).and_raise(StandardError.new('トピック更新エラー'))

        expect do
          described_class.create_with_history!(
            topic: topic,
            author: author,
            content: content
          )
        end.to raise_error(StandardError, 'トピック更新エラー')
        .and change(described_class, :count).by(0)
        .and change(CommentHistory, :count).by(0)
        .and change { topic.reload.total_comment }.by(0)
      end
    end

    context '同時書き込み' do
      it '複数のスレッドが同時にコメントを作成しても、トピックの総コメント数が正確に更新される' do
        thread_count = 3
        threads = []
        created_comments = []

        thread_count.times do
          threads << Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              ActiveRecord::Base.transaction do
                created_comments << described_class.create_with_history!(
                  topic: topic,
                  author: author,
                  content: content
                )
              end
            end
          end
        end

        threads.each(&:join)

        expect(created_comments.size).to eq(thread_count)
        expect(described_class.count).to eq(thread_count)
        expect(CommentHistory.count).to eq(thread_count)

        topic.reload
        expect(topic.total_comment).to eq(thread_count)
      end
    end
  end

  describe '#update_content!' do
    let!(:comment) { create(:comment) }
    let(:new_content) { '更新されたコメント内容' }

    context '基本機能' do
      it 'コメント内容を更新し、新しい履歴を作成する' do
        initial_version = comment.current_version_no

        expect do
          comment.update_content!(new_content)
        end.to change { comment.reload.content }
        .to(new_content)
        .and change(comment, :current_version_no)
        .from(initial_version).to(initial_version + 1)
        .and change(CommentHistory, :count).by(1)
        .and change { comment.histories.last.version_no }
        .from(initial_version).to(initial_version + 1)
        .and change { comment.histories.last.content }
        .to(new_content)
      end
    end

    context 'トランザクション' do
      it '履歴の作成に失敗した場合、全体がロールバックされる' do
        initial_content = comment.content
        initial_version = comment.current_version_no
        history_count   = CommentHistory.count

        allow_any_instance_of(CommentHistory).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(CommentHistory.new))

        expect do
          comment.update_content!(new_content)
        end.to raise_error(ActiveRecord::RecordInvalid)

        aggregate_failures do
          expect(comment.reload.content).to eq(initial_content)
          expect(comment.current_version_no).to eq(initial_version)
          expect(CommentHistory.count).to eq(history_count)
        end
      end
    end

    context '同時書き込み' do
      it '複数のスレッドが同時に同じコメントを更新しても、バージョン番号の整合性が保たれる' do
        initial_version = comment.current_version_no
        comment_histories_count = comment.histories.count

        thread_count = 3
        threads = []
        update_results = []

        thread_count.times do |i|
          threads << Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              ActiveRecord::Base.transaction do
                local_comment = described_class.find(comment.id)
                local_comment.update_content!("更新 #{i + 1}")
                update_results << { success: true, version: local_comment.current_version_no }
              end
            end
          end
        end

        threads.each(&:join)

        comment.reload
        expect(comment.current_version_no).to eq(initial_version + thread_count)
        expect(comment.histories.count).to eq(comment_histories_count + thread_count)

        history_versions = comment.histories.pluck(:version_no).sort
        expect(history_versions).to eq((initial_version..(initial_version + thread_count)).to_a)
      end
    end
  end
end
