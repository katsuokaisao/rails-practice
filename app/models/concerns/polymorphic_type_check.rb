# frozen_string_literal: true

# == PolymorphicTypeCheck
#
# include したモデルに対して、指定された polymorphic 関連の type 判定メソッドを自動生成する Concern。
#
# 例:
#   class Report < ApplicationRecord
#     POLYMORPHIC_FLAG_ASSOC_NAME = :reportable
#     POLYMORPHIC_FLAG_CLASSES    = [User, Comment].freeze
#
#     include PolymorphicTypeCheck
#     belongs_to :reportable, polymorphic: true
#   end
#
#   # 自動生成されるメソッド
#   # - reportable_type_user?     → reportable_type が "User"     のとき true
#   # - reportable_type_comment?  → reportable_type が "Comment"  のとき true
#

module PolymorphicTypeCheck
  extend ActiveSupport::Concern

  included do
    unless const_defined?(:POLYMORPHIC_FLAG_ASSOC_NAME) && const_defined?(:POLYMORPHIC_FLAG_CLASSES)
      raise "#{name} must define POLYMORPHIC_FLAG_ASSOC_NAME and POLYMORPHIC_FLAG_CLASSES"
    end

    assoc_name  = const_get(:POLYMORPHIC_FLAG_ASSOC_NAME)
    type_column = :"#{assoc_name}_type"

    const_get(:POLYMORPHIC_FLAG_CLASSES).map(&:to_s).each do |klass_name|
      method_name = :"#{assoc_name}_type_#{klass_name.demodulize.underscore}?"
      next if method_defined?(method_name)

      define_method(method_name) { public_send(type_column) == klass_name }
    end
  end
end
