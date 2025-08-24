# frozen_string_literal: true

# アプリケーションヘルパー
#
# 全てのビューで共通して使用できるヘルパーメソッドを提供する。
# CSSクラス名の生成やコントローラー・アクション情報の取得機能を含む。
module ApplicationHelper
  def root_class_name
    [data_controller_name, data_action_name].join(' ')
  end

  def data_controller_name
    "#{controller_path.gsub('/', '_')}_controller"
  end

  def data_action_name
    "#{action_name}_action"
  end
end
