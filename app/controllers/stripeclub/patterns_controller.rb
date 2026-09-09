module Stripeclub
  class PatternsController < ApplicationController
    # Twelve is two rows of cards at the page's width. It is a layout
    # decision, so it lives beside the layout and not in the model.
    PER_PAGE = 12

    before_action :set_pattern, only: %i[ show edit update destroy ]

    # Narrowed by a name as typed, by which way the stripes lean, by a tag,
    # and put in one of three orders; the filters are the library's registers
    # and the scopes are the pattern's.
    def index
      @sort = Pattern::SORTS.key?(params[:sort]) ? params[:sort] : "name"
      @lean = Pattern::LEANS.key?(params[:lean]) ? params[:lean] : nil
      @tag = params[:tag].presence
      @tags = Pattern.all_tags
      @total = Pattern.count

      narrowed = Pattern.name_matching(params[:q]).leaning(@lean)
      narrowed = narrowed.tagged(@tag) if @tag
      @pages = [ (narrowed.count / PER_PAGE.to_f).ceil, 1 ].max
      @page = params[:page].to_i.clamp(1, @pages)
      @patterns = narrowed.sorted(@sort).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
    end

    # The page's four surfaces: what the pattern is made of, how it is
    # finished, what it wears, how it leaves.
    SECTIONS = %w[ compose finish dress export ].freeze

    def show
      @section = SECTIONS.include?(params[:section]) ? params[:section] : "compose"
    end

    def new
      @pattern = Pattern.new(slot_count: 2)
    end

    def edit
    end

    def create
      @pattern = Pattern.new(composition_params)

      if @pattern.save
        redirect_to @pattern, notice: "#{@pattern.name} composed."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @pattern.update(pattern_params)
        redirect_to @pattern, notice: "#{@pattern.name} saved."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @pattern.destroy!

      redirect_to patterns_path, notice: "#{@pattern.name} taken away."
    end

    private
      def set_pattern
        @pattern = Pattern.find(params[:id])
      end

      # The slot count is settled when the pattern is composed and moves after
      # that only through "+" and "−", which preserve the composition and refuse
      # to strand a stripe. Left editable here it would be a number someone
      # could type over, and the values and stripes under it would not follow.
      def pattern_params
        params.expect(pattern: [ :name, :angle, :tag_list ])
      end

      def composition_params
        params.expect(pattern: [ :name, :angle, :slot_count, :tag_list ])
      end
  end
end
