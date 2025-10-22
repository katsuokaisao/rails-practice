# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def enum_i18n(enum_name)
    return nil if send(enum_name).nil?

    I18n.t!("enums.#{model_name.i18n_key}.#{enum_name}.#{send(enum_name)}")
  end
end
