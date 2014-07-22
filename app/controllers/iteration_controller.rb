class IterationController < ApplicationController
  before_filter :check_api_token

  def index
    redirect_to :action => :view if @api_token
  end

  def view
    return redirect_to :action => :index unless @api_token

    if session[:iteration_presenter]
      @iteration_presenter = session[:iteration_presenter]
    else
      @iteration_presenter = IterationPresenter.new(@api_token, params[:project_id])
      session[:iteration_presenter] = @iteration_presenter
    end
  end

  private

    def check_api_token
      session[:api_token] = params[:api_token] if params[:api_token]
      @api_token          = session[:api_token]
    end
end
