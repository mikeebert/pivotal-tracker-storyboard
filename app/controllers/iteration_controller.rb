class IterationController < ApplicationController
  before_filter :check_api_token, :only => :view
  def index
  end

  def view
    redirect_to :action => :index unless @api_token

    @iteration_presenter = IterationPresenter.new(@api_token, params[:project_id])
  end

  private

    def check_api_token
      session[:api_token] = params[:api_token] if params[:api_token]
      @api_token          = session[:api_token]
    end
end
