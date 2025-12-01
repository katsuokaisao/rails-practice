# frozen_string_literal: true

create_table 'tenants', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'name',        null: false, comment: 'テナント名（表示用）'
  t.string   'slug',        null: false, comment: 'テナント識別子'
  t.text     'description', null: false, comment: 'テナントの説明'
  t.string 'unsubscribed_user_topic_policy',
           null: false,
           default: 'keep_visible',
           comment: '退会ユーザーのトピック表示ポリシー（keep_visible / lock / delete）'
  t.string 'unsubscribed_user_comment_policy',
           null: false,
           default: 'keep_visible',
           comment: '退会ユーザーのコメント表示ポリシー（keep_visible / hide_content / delete）'
  t.string 'applying_policy',
           null: false,
           default: 'idle',
           comment: 'ポリシー適用状態（idle / progress / failed）'
  t.datetime 'created_at',  null: false
  t.datetime 'updated_at',  null: false

  t.index ['slug'], name: 'idx_tenants_slug', unique: true
end
