module IterationHelper
  def story_icon(type)
    icon = case type
           when "bug" then "fire"
           when "chore" then "cog"
           when "feature" then "star"
           else "question-sign"
           end
    content_tag(:span, "", class: "glyphicon glyphicon-#{icon}")
  end

  def story_state_color(state)
    case state
    when "started"                then "info"
    when "finished"               then "warning"
    when "delivered", "accepted"  then "success"
    else "default"
    end
  end

  def role_initials(story, role)
    role_initials = initials(story.send(role))

    label = role_label(role)

    if needs_role_assigned?(role, story.current_state) && role_initials.blank?
      content_tag(:span, "Need #{label}", class: "label label-danger")
    elsif !role_initials.blank?
      "#{label}: #{role_initials}"
    end

  end

  private
    def initials(people)
      people = [people].compact unless people.is_a? Array
      people.map { |person| content_tag(:strong, content_tag(:abbr, person.initials, title: person.name, class: "initialism")) }.join ", "
    end

    def role_label(role)
      case role
      when "requester" then "Req"
      when "developers" then "Dev"
      when "reviewers" then "CR"
      when "qa" then "QA"
      end
    end

    def needs_role_assigned?(role, story_state)
      case role
      when "developers" then ["started", "finished", "delivered", "accepted"].include?(story_state)
      when "reviewers", "qa" then ["finished", "delivered", "accepted"].include?(story_state)
      end
    end
end
