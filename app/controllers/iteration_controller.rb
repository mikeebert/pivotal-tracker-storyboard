class IterationController < ApplicationController
  before_filter :check_api_token

  def index
    redirect_to :action => :view if @api_token
  end

  def view
    return redirect_to :action => :index unless @api_token

    @iteration_presenter = cached_iteration_presenter
  end

  def refresh
    session.delete :iteration_presenter

    redirect_to :action => :view
  end

  private

    def check_api_token
      session[:api_token] = params[:api_token] if params[:api_token]
      @api_token          = session[:api_token]
    end

    def cached_iteration_presenter
      session[:iteration_presenter] ||= IterationPresenter.new(@api_token, params[:project_id])
    end
end
