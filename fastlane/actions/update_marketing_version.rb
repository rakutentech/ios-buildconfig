module Fastlane
  module Actions
    class UpdateMarketingVersionAction < Action
      def self.run(params)
        UI.message "Setting marketing version #{params[:version_number]}"

        project = Xcodeproj::Project.open(params[:xcodeproj])
        configs = project.objects.select { |obj| select_build_configuration_predicate(nil, obj) }
        configs.each do |config|
          # skip test targets
          if config.build_settings["BUNDLE_LOADER"] == nil
            UI.message "- #{config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"]}"
            config.build_settings["MARKETING_VERSION"] = params[:version_number]
          end
        end
        project.save
      end

      private_class_method
      def self.select_build_configuration_predicate(name, configuration)
        is_build_valid_configuration = configuration.isa == "XCBuildConfiguration" && !configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"].nil?
        is_build_valid_configuration &&= configuration.name == name unless name.nil?
        return is_build_valid_configuration
      end

      def self.description
        "Updates MARKETING_VERSION in all targets of given xcodeproj"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :version_number,
                                         description: "Version number (x.y.z) to set",
                                         is_string: true,
                                         optional: false
            ),
            FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                         description: "A path to .xcodeproj file",
                                         is_string: true,
                                         optional: false
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
