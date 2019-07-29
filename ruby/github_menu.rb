require "time"

require "graphql/client"
require "graphql/client/http"
require "relative_time"

SCHEMA_PATH = "tmp/github_schema.json"
OWNER, REPO = ENV.fetch("GH_REPO").split("/")

module GitHub
  HTTP = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      {"Authorization": "bearer #{ENV.fetch("GH_TOKEN")}"}
    end
  end

  # Load schema from disk if it exists
  # TODO expire when older than 24 hours
  if File.exist?(SCHEMA_PATH)
    Schema = GraphQL::Client.load_schema(SCHEMA_PATH)
  else
    Schema = GraphQL::Client.load_schema(HTTP)
    GraphQL::Client.dump_schema(HTTP, SCHEMA_PATH)
  end

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end

PullRequestQuery = GitHub::Client.parse <<~GRAPHQL
                                          query {
                                            repository(owner: #{OWNER}, name:#{REPO}) {
      pullRequests(last: 100, states: OPEN, orderBy: {field: CREATED_AT, direction: DESC}) {
        nodes {
          title
          createdAt
          url
          headRefName
          reviews(last: 10) {
            nodes {
              state
            }
          }
          author {
            login
            ... on User {
              name
            }
          }
        }
      }
    }
  }
                                        GRAPHQL

TEAM = ENV.fetch("GH_TEAM").split(" ")

Icons = {
  "PENDING" => "",
  "COMMENTED" => "💬",
  "APPROVED" => "✅",
  "CHANGES_REQUESTED" => "🚫",
  "DISMISSED" => "",
}

def review_statuses(reviews)
  reviews.map { |r| Icons[r.state] }.join
end

response = GitHub::Client.query(PullRequestQuery)
team_prs = response.data.repository.pull_requests.nodes.select { |pr| TEAM.include?(pr.author.login) }

puts "GitHub (#{team_prs.size})\n---"

if team_prs.size > 0
  team_prs.each do |pr|
    created = RelativeTime.in_words(Time.iso8601(pr.created_at))
    reviews = review_statuses(pr.reviews.nodes)
    puts "#{pr.title} #{reviews}|href=#{pr.url}"
    puts "#{pr.author.login}, #{created}|size=12"
  end
end
