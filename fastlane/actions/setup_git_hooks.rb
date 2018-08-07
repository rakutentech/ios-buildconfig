require 'fileutils'

module Fastlane
  module Actions
    class SetupGitHooksAction < Action
      def self.run(params)
        UI.message("Set up git hooks: clang-format pre-commit hook")

        # download clang-format config
        sh("curl -s -o .clang-format https://raw.githubusercontent.com/rakutentech/ios-buildconfig/master/.clang-format")

        # download pre-commit hook and copy to .git/hooks/pre-commit
        sh("curl -s -o pre-commit https://raw.githubusercontent.com/rakutentech/ios-buildconfig/master/scripts/check-files-clang")
        sh("chmod +x pre-commit")
        FileUtils.rm '.git/hooks/pre-commit', :force => true
        FileUtils.mkdir_p('.git/hooks')
        FileUtils.mv 'pre-commit', '.git/hooks/', :force => true
      end

      def self.description
        "Set up git hooks: clang-format pre-commit hook"
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
