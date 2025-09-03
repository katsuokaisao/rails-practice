# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  before do
    allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return('1.2.3.4')
  end

  describe 'サインインのレートリミット' do
    let(:sign_in_path) { '/users/sign_in' }
    let(:params) { { user: { nickname: 'testuser', password: 'password123' } } }

    it '制限回数内のリクエストは成功すること' do
      5.times do
        post sign_in_path, params: params
        expect(response.status).not_to eq 429
      end
    end

    it '制限回数を超えるとレートリミットが適用されること' do
      5.times do
        post sign_in_path, params: params
      end

      post sign_in_path, params: params

      expect(response.status).to eq 429
      expect(response.headers).to include('Retry-After')
      expect(response.parsed_body).to include('error' => 'レート制限を超えました。しばらく待ってから再試行してください。')
    end
  end

  describe 'トピック作成のレートリミット' do
    let(:topics_path) { '/topics' }
    let(:user) { create(:user) }
    let(:params) { { topic: { title: 'テストトピック', content: 'テスト内容' } } }

    before do
      login_as(user)
    end

    it '制限回数内のリクエストは成功すること' do
      10.times do
        post topics_path, params: params
        expect(response.status).not_to eq 429
      end
    end

    it '制限回数を超えるとレートリミットが適用されること' do
      10.times do
        post topics_path, params: params
      end

      post topics_path, params: params

      expect(response.status).to eq 429
      expect(response.headers).to include('Retry-After')
    end
  end

  describe 'コメント作成のレートリミット' do
    let(:comments_path) { '/comments' }
    let(:user) { create(:user) }
    let(:topic) { create(:topic) }
    let(:params) { { comment: { content: 'テストコメント', topic_id: topic.id } } }

    before do
      login_as(user)
    end

    it '制限回数内のリクエストは成功すること' do
      15.times do
        post comments_path, params: params
        expect(response.status).not_to eq 429
      end
    end

    it '制限回数を超えるとレートリミットが適用されること' do
      15.times do
        post comments_path, params: params
      end

      post comments_path, params: params

      expect(response.status).to eq 429
      expect(response.headers).to include('Retry-After')
    end
  end

  describe 'レポート作成のレートリミット' do
    let(:reports_path) { '/reports' }
    let(:user) { create(:user) }
    let(:comment) { create(:comment) }
    let(:params) do
      {
        report: {
          target_type: 'Comment',
          target_id: comment.id,
          reason_type: 'harassment',
          reason_text: 'テスト理由'
        }
      }
    end

    before do
      login_as(user)
    end

    it '制限回数内のリクエストは成功すること' do
      5.times do
        post reports_path, params: params
        expect(response.status).not_to eq 429
      end
    end

    it '制限回数を超えるとレートリミットが適用されること' do
      5.times do
        post reports_path, params: params
      end

      post reports_path, params: params

      expect(response.status).to eq 429
      expect(response.headers).to include('Retry-After')
    end
  end
end
