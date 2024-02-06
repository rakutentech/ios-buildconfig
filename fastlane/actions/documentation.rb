require 'fileutils'

module Fastlane
  module Actions
    class DocumentationAction < Action
      def self.run(params)
        module_name = params[:module_name]
        module_version = params[:module_version]
        docgen_script = params[:docgen_script] || ""

        UI.message("Generate documentation for #{module_name}-#{module_version}")

        workspace = ENV['WORKSPACE'] || "./"

        Dir.chdir(workspace) do
          if docgen_script.empty?
            # running default script
            sh "git clone https://github.com/rakutentech/ios-buildconfig"
            sh "mv ios-buildconfig/jazzy_themes ."
            sh "rm -rf ios-buildconfig"
            sh "bundle exec jazzy --output artifacts/docs/#{module_version} --theme jazzy_themes/apple_versions"
          else
            sh("#{docgen_script} #{module_name} #{module_version}")
          end
        end
      end

      def self.description
        "Generate documentation for sdk module using custom themed jazzy or shell script passed in `docgen_command` optional parameter"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :module_name,
                                       description: "name of the module"
                                       ),
          FastlaneCore::ConfigItem.new(key: :module_version,
                                       description: "version of the module"
                                       ),
          FastlaneCore::ConfigItem.new(key: :docgen_script,
                                       description: "a custom shell script that generates documentation (optional)",
                                       optional: true
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
