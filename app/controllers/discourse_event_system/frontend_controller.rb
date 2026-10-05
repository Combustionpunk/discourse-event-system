# frozen_string_literal: true

module DiscourseEventSystem
  class FrontendController < ApplicationController
    requires_plugin PLUGIN_NAME
    # The access checks below must run on full page loads, which check_xhr would short-circuit.
    skip_before_action :check_xhr, only: %i[events event]

    def index
    end

    # /events is organiser back office; members use the RC Meetings category.
    def events
      return redirect_to(DesEvent.meetings_url) unless DesEvent.organiser?(current_user)
      render "default/empty"
    end

    # Members go to the event's topic; managers keep the back-office page.
    def event
      event = DesEvent.find_by(id: params[:id])
      raise Discourse::NotFound if event.nil?
      return render("default/empty") if event.manageable_by?(current_user)
      raise Discourse::NotFound if event.draft? || event.topic.nil?
      redirect_to event.topic.relative_url
    end
  end
end
