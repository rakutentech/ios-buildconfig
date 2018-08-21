require 'fileutils'

module Fastlane
  module Actions
    class ApplyCodestyleAction < Action
      def self.run(params)
        UI.message("Format Objective-C code files with clang-format tool")

        begin
          # download latest clang-format config
          sh("curl -s -o .clang-format https://raw.githubusercontent.com/rakutentech/ios-buildconfig/master/.clang-format")

          folder = ENV['REM_MODULE_NAME'] || ENV['REM_FL_TESTS_SLATHER_BASENAME']
          format_command = "find #{folder}/ -iname *.h -o -iname *.m | xargs clang-format -style=file -fallback-style=none"

          if (params[:check_only] == true)
            output_path = 'artifacts/clang-format-report.txt'
            UI.message("Running checks only, outputting results to #{output_path}")
            sh(format_command + " > #{output_path}")
          else
            UI.message("Formatting files in-place")
            sh(format_command + " -i")
          end
        rescue
          handle_format_error(params[:ignore_exit_status], $?.exitstatus)
        end
      end

      def self.description
        "Format Objective-C code files in-place with clang-format tool"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :ignore_exit_status,
                                       description: " when error occurs ignore exit status and continue",
                                       optional: true,
                                       default_value: true,
                                       is_string: false
                                       ),
          FastlaneCore::ConfigItem.new(key: :check_only,
                                       description: "do not format source files in-place, store the check result in artifacts/clang-format-report.txt",
                                       optional: true,
                                       default_value: false,
                                       is_string: false
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

      def self.handle_format_error(ignore_exit_status, exit_status)
        if ignore_exit_status
          failure_suffix = 'which would normally fail the build.'
          secondary_message = 'fastlane will continue because the `ignore_exit_status` option was used! 🙈'
        else
          failure_suffix = 'which represents a failure.'
          secondary_message = 'If you want fastlane to continue anyway, use the `ignore_exit_status` option. 🙈'
        end

        UI.important("")
        UI.important("Formatting finished with exit code #{exit_status}, #{failure_suffix}")
        UI.important(secondary_message)
        UI.important("")
        UI.user_error!("Formatting finished with errors (exit code: #{exit_status})") unless ignore_exit_status
      end
    end
  end
end

# vim:syntax=ruby:et:sts=2:sw=2:ts=2:ff=unix:
