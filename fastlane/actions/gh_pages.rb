require 'fileutils'
require 'yaml'
require 'uri'

module Fastlane
  module Actions
    class GhPagesAction < Action
      def self.run(params)
        deploy_key = params[:deploy_key]
        github_token = params[:github_token]
        ghpages_url = params[:ghpages_url]

        # Check necessary input data
        UI.user_error!("Missing `_versions` file") unless File.exist?("_versions")
        UI.user_error!("Missing `.jazzy.yaml` file") unless File.exist?(".jazzy.yaml")
        module_version = YAML.load(File.read(".jazzy.yaml"))["module_version"]
        UI.user_error!("Missing `module_version` parameter in .jazzy.yaml file") unless module_version != nil
        module_name = YAML.load(File.read(".jazzy.yaml"))["module"]
        UI.user_error!("Missing `module` parameter in .jazzy.yaml file") unless module_name != nil
        docs_folder = "artifacts/docs"

        if deploy_key == nil && github_token == nil
          UI.user_error!(":deploy_key or :github_token must be specified")
        end
        if !ghpages_url.include?("git@") && deploy_key != nil
          UI.user_error!(":ghpages_url must be a SSH URL when using :deploy_key")
        end
        git_ssh_command = deploy_key == nil ? "" : "ssh -i #{deploy_key} -o IdentitiesOnly=yes"

        # Prepare environment
        FileUtils.rm_rf(docs_folder)
        sh "GIT_SSH_COMMAND='#{git_ssh_command}' git clone --single-branch --branch gh-pages #{ghpages_url} #{docs_folder}"
        FileUtils.rm_rf("#{docs_folder}/#{module_version}")

        # Generate docs
        UI.message("Generating documentation")
        Actions::DocumentationAction.run(module_name: module_name, 
                                         module_version: module_version,
                                         docgen_script: ENV["REM_FL_DOCS_GENERATION_SCRIPT"])

        # Generate html files
        versions_string = File.readlines("_versions").map{|line| "\"#{line.strip}\""}.join(",")
        versions_js = "const Versions = [" + versions_string + "];"
        File.open("#{docs_folder}/versions.js", "w") { |f| f.write versions_js }
        File.open("#{docs_folder}/index.html", "w") { |f| f.write "<html><head><meta http-equiv=\"refresh\" content=\"0; URL=#{module_version}/index.html\" /></head></html>" }

        UI.message("Deploying documentation")
        # Deploy to GitHub Pages
        git_cmd_config = "--git-dir=#{docs_folder}/.git --work-tree=#{docs_folder}/"
        sh "git #{git_cmd_config} add . -f"
        sh "git #{git_cmd_config} commit -m \"Deploy Jazzy docs for version #{module_version}\""

        if deploy_key != nil then
          sh "GIT_SSH_COMMAND='#{git_ssh_command}' git #{git_cmd_config} push origin gh-pages"
        else
          gh_host = URI.parse(ghpages_url).host
          sh "git #{git_cmd_config} config url.\"https://x-token-auth:#{github_token}@#{gh_host}\".InsteadOf https://#{gh_host}"
          sh "git #{git_cmd_config} push origin gh-pages"
        end

        # Cleanup
        FileUtils.rm_rf("jazzy_themes")
      end

      def self.description
        "Generate Jazzy documentation for sdk module and publish it to GitHub Pages"
      end

      def self.available_options
        conflict_block = Proc.new do |other|
          UI.user_error! "Unexpected conflict with option #{other}" unless [:github_token, :deploy_key].include?(other)
          UI.message "Ignoring :github_token in favor of :deploy_key"
        end
        [
          FastlaneCore::ConfigItem.new(key: :ghpages_url,
                                       description: "Repository URL to store generated documentation (gh-pages branch)"),
          FastlaneCore::ConfigItem.new(key: :deploy_key,
                                       description: "Path to private SSH GitHub Deploy Key (use with a SSH-based :ghpages_url)",
                                       optional: true,
                                       conflicting_options: [:github_token],
                                       conflict_block: conflict_block),
          FastlaneCore::ConfigItem.new(key: :github_token,
                                       description: "GitHub API token for publising generated documentation",
                                       optional: true,
                                       conflicting_options: [:deploy_key],
                                       conflict_block: conflict_block)
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
