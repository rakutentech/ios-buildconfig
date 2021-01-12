def call() {
  	slackSend channel: "${env.SLACK_CHANNEL_SDK}",
        color: 'good',
        message: "${currentBuild.fullDisplayName} is back to normal (<${env.BUILD_URL}|Open>)"
}