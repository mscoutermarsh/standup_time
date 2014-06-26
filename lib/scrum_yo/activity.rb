module ScrumYo
  class Activity
    attr_reader :github_activity, :user

    def initialize
      @user = ScrumYo::User.new
      @github_activity = load_activities
    end

    private

    def load_activities(page = 1)
      activities = @user.github_client.user_events(@user.username, page: page)

      if older_than_one_day(activities.last)
        return filter_activity(activities)
      else
        activities.push(*load_activities(page + 1))
      end
    end

    def older_than_one_day(event)
      (Time.now.utc - event.created_at) / 3600 > 24
    end

    def filter_activity(events)
      events.select! { |e| %w{PushEvent PullRequestEvent}.include? e.type }

      events.each do |event|
        if event.payload.commits
          event.payload.commits.select! { |commit| @user.emails.include? commit.author.email }
        end
      end

      events
    end

  end
end
