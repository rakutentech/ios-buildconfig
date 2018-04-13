module Fastlane
  module Actions
    class NotifyGitpubAction < Action
      def self.run(params)
        status = params[:status]
        UI.message("If running on CI, notify job status #{status} to gitpub")

        return unless Helper.ci?

        # set up notification variables
        job_url = ENV['JOB_URL']
        job_name = ENV['JOB_NAME']
        build_number = ENV['BUILD_NUMBER']
        git_url = ENV['GIT_URL']
        gitpub_url = ENV['REM_FL_GITPUB_URL']

        # use the 'from' branch so we get the reviewed commit and not the automatic merge commit
        git_branch_env = ENV['GIT_BRANCH']
        git_branch = git_branch_env.dup
        git_branch.sub! 'merge', 'from'

        jenkins_job_url = "#{job_url}/#{build_number}/console"

        reviewed_commit = `git ls-remote #{git_url} #{git_branch} | /usr/bin/cut -f1 | tr -d '\n'`

        puts "Build status #{status}, git url #{git_url}, git branch #{git_branch}, reviewed commit #{reviewed_commit}, gitpub job #{jenkins_job_url}"

        sh "curl -s -n -H '"'Content-Type: application/json'"' -X POST '#{gitpub_url}/rest/build-status/1.0/commits/#{reviewed_commit}' -d '{\"state\":\"#{status}\",\"key\":\"#{job_url}\",\"name\":\"#{job_name} ##{build_number}\",\"url\":\"#{jenkins_job_url}\"}' --trace-ascii -"

      end

      def self.description
        "Notify Jenkins build status to gitpub"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :status,
                                       description: "status of CI job"
                                       )
        ]
      end

      def self.output
      end

      def self.authors
        ["rem"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
