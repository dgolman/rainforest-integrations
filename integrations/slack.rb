require "active_support/core_ext/string/strip"
require "active_support/core_ext/string/filters"

module Rainforest
  module Integrations
    class Slack < Base
      include HttpIntegration
      include TextRenderer

      config do
        string :slack_url
      end

      def on_event(event)
        return if url.empty?

        body = if event.name == "of_test_failure"
                 { text: message_text(event),
                   attachments: failed_step_attachments(event) }
               else
                 { attachments: attachments(event) }
               end

        response = post url, body: body.to_json
        # Slack errors are still `200 OK`. For shame.
        unless response.parsed_response["ok"]
          msg = "Connection refused, invalid URL. (#{response.parsed_response["error"]})"
          raise ConfigurationError.new(msg)
        end

      rescue Addressable::URI::InvalidURIError => ex
        msg = "Invalid URL. It should look like https://you.slack.com/services/hooks/incoming-webhook?token=xyz"
        raise ConfigurationError.new(msg, original_exception: ex)
      end

      def message_text(event)
        browser_result = event.browser_result
        "Your test " +
        "<#{event.ui_link}|#{browser_result["failing_test"]["title"].inspect}> " +
        "failed in #{browser_result["name"]} for run " +
        "#{run_link(event.run, event.ui_link)}."
      end

      def attachments(event)
        text = render_text(event)
        color = event.is_failure ? 'danger' : 'good'

        [
          {
            text: text,
            fallback: text,
            color: color
          }
        ]
      end

      def failed_step_attachments(event)
        data = []

        browser_result = event.browser_result
        steps = browser_result["failing_test"]["steps"]
        steps.each.with_index do |step, i|
          result = step["browsers"].first
          next unless result["result"] == "failed"
          data << render_attachment(event, browser_result, step, i)
        end

        data
      end

      def render_attachment(event, browser_result, step, idx)
        result = step["browsers"].first

        color = 'danger'

        text = "Step ##{idx+1} #{result["result"]}: #{truncate(step["action"])} - #{truncate(step["response"])}"

        {
          fallback: text,
          mrkdwn_in: ["fields"],
          color: color,
          text: text,
          fields: result["feedback"].map.with_index do |feedback, idx|
            next unless feedback["note"].present?
            {
              title: "Feedback from Tester ##{idx+1}",
              value: feedback["note"]
            }
          end.compact
        }
      end

      # override the text helpers to use slack-flavored links
      def completion_text(event)
        run = event.run
        "Your Rainforest Run #{run_link(run, event.ui_link)} #{run["result"]}"
      end

      def error_text(event)
        run = event.run
        "Your Rainforest Run #{run_link(run, event.ui_link)} errored: #{run["error_reason"].inspect}"
      end

      def webhook_timeout_text(event)
       "Your Rainforest run #{run_link(event.run, event.ui_link)} timed out due to your webhook failing. If you need a hand debugging it, please let us know via email at team@rainforestqa.com."
      end

      def run_link(run, href)
        "<#{href}|##{run["id"]}>"
      end

      def truncate(str, len: 30)
        str.truncate(len, separator: /\s+/)
      end

      def url
        config.slack_url
      end
    end
  end
end
