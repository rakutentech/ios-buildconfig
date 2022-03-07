require 'fileutils'

module Fastlane
  module Actions
    class SetupGitHooksAction < Action
      def self.run(params)
        UI.message "Setup git hook: [pre-commit] Detect hardcoded secrets using Gitleaks"

        raise UI.user_error! "pre-commit git hook already exists" unless !File.file?('.git/hooks/pre-commit')

        begin
          sh "command -v gitleaks"
        rescue => ex
          UI.user_error! "gitleaks not found (try running:  brew install gitleaks)"
          raise
        end

        FileUtils.mkdir_p('.git/hooks')
        FileUtils.touch('.git/hooks/pre-commit')
        precommitsh = <<~EOS
          #!/bin/sh
          gitleaks protect --verbose --redact --staged
        EOS
        File.write('.git/hooks/pre-commit', precommitsh)
        FileUtils.chmod("+x", '.git/hooks/pre-commit')
      end

      def self.description
        "Setup git hook(s)"
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
