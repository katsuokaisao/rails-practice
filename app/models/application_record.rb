# frozen_string_literal: true

# 全てのActiveRecordモデルの基底クラス。
# アプリケーション全体で共通するモデルの設定や機能を提供する。
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
