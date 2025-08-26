# frozen_string_literal: true

module Pagination
  Result = Data.define(:records, :page, :per, :ahead, :window_numbers, :out_of_bounds)

  class Paginator
    WINDOW_HALF = 4
    DEFAULT_LOOKAHEAD = 4

    def initialize(relation:, page:, per:, lookahead: DEFAULT_LOOKAHEAD)
      @relation  = relation
      @page      = page.to_i <= 0 ? 1 : page.to_i
      @per       = per.to_i  <= 0 ? 20 : per.to_i
      @lookahead = lookahead.to_i <= 0 ? DEFAULT_LOOKAHEAD : lookahead.to_i
    end

    def call
      records       = fetch_page(relation, page, per)
      out_of_bounds = records.empty? && page > 1
      ahead         = pages_ahead(relation, page, per, lookahead)
      window        = build_window(page, ahead)

      Result.new(
        records: records,
        page: page,
        per: per,
        ahead: ahead,
        window_numbers: window,
        out_of_bounds: out_of_bounds
      )
    end

    private

    attr_reader :relation, :page, :per, :lookahead

    def fetch_page(rel, page, per)
      offset = (page - 1) * per
      rel.offset(offset).limit(per)
    end

    # 現在ページ「の次」から lookahead*per だけ覗き、完全ページ数を返す
    def pages_ahead(rel, page, per, lookahead)
      offset_after_current = page * per
      max_rows_to_peek     = per * lookahead

      remaining = rel.offset(offset_after_current)
                     .limit(max_rows_to_peek)
                     .unscope(:order)
                     .count

      # 余りがある場合も1ページ進めるとみなす
      pages = (remaining.to_f / per).ceil

      [pages, lookahead].min
    end

    # 左右の表示ウィンドウ（右側は ahead が足りなければ短縮）
    def build_window(current, ahead)
      left  = [current - 1, WINDOW_HALF].min
      right = [ahead, WINDOW_HALF].min
      ((current - left)..(current + right)).to_a
    end
  end
end
