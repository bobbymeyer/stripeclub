module Stripeclub
  class PatternsController < ApplicationController
    # Ten is what fits above the fold at the measure the page is set to. It is a
    # layout decision, so it lives beside the layout and not in the model.
    PER_PAGE = 10

    before_action :set_pattern, only: %i[ show edit update destroy ]

    def index
      @pages = [ (Pattern.count / PER_PAGE.to_f).ceil, 1 ].max
      @page = params[:page].to_i.clamp(1, @pages)
      @patterns = Pattern.order(:name).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
    end

    def show
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
        params.expect(pattern: [ :name, :angle ])
      end

      def composition_params
        params.expect(pattern: [ :name, :angle, :slot_count ])
      end
  end
end
