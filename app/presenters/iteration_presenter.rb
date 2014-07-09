module PivotalTracker
  class Story
    attr_accessor :requester
    attr_accessor :developers
    attr_accessor :reviewers
    attr_accessor :qa
    attr_accessor :github_urls
  end
end

class IterationPresenter
  attr_reader :selected_project_id

  def initialize(api_token, project_id = nil)
    raise ArgumentError unless api_token
    PivotalTracker::Client.token = api_token
    @selected_project_id = project_id.to_i if project_id
  end

  def projects
    @projects ||= PivotalTracker::Project.all("fields=name,current_velocity").
      map {|project| project.name.gsub!("NetCredit - ", ""); project }
  end

  def projects_velocity
    @projects_velocity ||= projects.inject(0) { |sum, p| sum + p.current_velocity }
  end

  def started_stories
    @started_stories ||= stories.select { |story| story.current_state == "started" }
  end

  def finished_stories
    @finished_stories ||= stories.select { |story| story.current_state == "finished" }.
      reject { |story| story.labels.map(&:name).include?("ready for qa") }
  end

  def reviewed_stories
    @reviewed_stories ||= stories.select { |story| story.labels.map(&:name).include?("ready for qa") }
  end

  def delivered_stories
    @delivered_stories ||= stories.select { |story| story.current_state == "delivered" }
  end

  def accepted_stories
    @accepted_stories ||= stories.select { |story| story.current_state == "accepted" }.reject do |story|
      labels = story.labels.map(&:name)
      labels.include?("released") || labels.include?("will not do")
    end
  end

  def released_stories
    @releaed_stories ||= stories.select { |story| story.current_state == "accepted" }.select do |story|
      labels = story.labels.map(&:name)
      labels.include?("released") || labels.include?("will not do")
    end
  end

  def columns
    columns = [
      { title: "Started",       stories: started_stories },
      { title: "Ready for CR",  stories: finished_stories },
      { title: "Ready for QA",  stories: reviewed_stories },
      { title: "Delivered",     stories: delivered_stories },
      { title: "Accepted",      stories: accepted_stories },
      { title: "Released",      stories: released_stories }
    ]
    columns.each do |column|
      column[:total] = column[:stories].inject(0) { |sum, story| sum + story.estimate }
    end
  end

  def iteration_date_range
    "#{Date.current.beginning_of_week} - #{Date.current.end_of_week}"
  end

  private
    def stories
      #return @stories if @stories
      @stories = if @selected_project_id
        project = projects.find { |project| project.id == @selected_project_id }
        project.stories.all(:search => iteration_stories_filter)
      else
        projects.inject([]) { |arr, project| arr + project.stories.all(:search => iteration_stories_filter) }
      end
      initialize_people_objects(@stories)
    end

    def iteration_stories_filter
      "(state:started OR state:finished OR state:delivered OR accepted_after:#{Date.current.beginning_of_week}) includedone:true"
    end

    def people
      @people ||= projects.map { |project| project.memberships.all.map(&:person) }.flatten.uniq
    end

    def person_by_initials(initials)
      people.find { |person| person.initials == initials }
    end

    def initials_from_description(story, role)
      story.description.to_s[/#{role}:\s*(.*)\s*/, 1].try(:strip)
    end

    def github_urls_from_description(story)
      story.description.to_s.scan(/(https:\/\/git.enova.com\/\S+)/).map(&:first)
    end

    def initialize_people_objects(stories)
      stories.map do |story|
        reviewer_initials = [initials_from_description(story, "CR1"), initials_from_description(story, "CR2")].compact
        qa_initials       = initials_from_description(story, "QA").to_s.split(",").map(&:strip)
        story.requester   = people.find { |person| story.requested_by_id == person.id }
        story.developers  = people.select { |person| story.owner_ids.include? person.id }
        story.reviewers   = reviewer_initials.map { |initials| person_by_initials(initials) }.compact
        story.qa          = qa_initials.map { |initials| person_by_initials(initials) }.compact
        story.github_urls = github_urls_from_description(story)
        story
      end
    end
end
