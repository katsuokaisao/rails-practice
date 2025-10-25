# frozen_string_literal: true

create_table 'tenants', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' do |t|
  t.string   'name',        null: false, comment: 'テナント名（表示用）'
  t.string   'identifier',  null: false, comment: 'テナント識別子'
  t.text     'description', null: false, comment: 'テナントの説明'
  t.datetime 'created_at',  null: false
  t.datetime 'updated_at',  null: false

  t.index ['name'], name: 'idx_tenants_name'
  t.index ['identifier'], name: 'idx_tenants_identifier', unique: true
end
