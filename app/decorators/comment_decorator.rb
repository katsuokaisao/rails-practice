# frozen_string_literal: true

class CommentDecorator < ApplicationDecorator
  decorates_association :author
end
