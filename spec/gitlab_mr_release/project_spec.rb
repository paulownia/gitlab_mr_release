require "logger"

describe GitlabMrRelease::Project do
  let(:project) do
    GitlabMrRelease::Project.new(
      api_endpoint:     api_endpoint,
      private_token:    private_token,
      project_name:     project_name,
    )
  end

  let(:api_endpoint)         { "http://example.com/api/v3" }
  let(:private_token)        { "XXXXXXXXXXXXXXXXXXX" }
  let(:project_name)         { "group/name" }
  let(:escaped_project_name) { "group%2Fname" }
  let(:web_url)              { "http://example.com/#{project_name}" }

  before do
    allow(project).to receive(:web_url) { web_url }
  end

  describe "#merge_request_iids_between" do
    subject { project.merge_request_iids_between(from, to) }

    before do
      stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/repository/compare?from=#{from}&to=#{to}").
        with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
        to_return(status: 200, body: read_stub("repository_compare.json"), headers: {})
    end

    let(:from) { "v0.0.2" }
    let(:to)   { "v0.0.3" }

    it { should contain_exactly(5, 6) }
  end

  describe "#generate_description" do
    subject { project.generate_description(iids, template) }

    let(:iids) { [5, 6] }

    let(:template) do
      <<-MARKDNWN.strip_heredoc
      # MergeRequests
      <% merge_requests.each do |mr| -%>
      * [ ] !<%= mr.iid %> <%= mr.title %> @<%= mr.author.username %>
      <% end -%>
      MARKDNWN
    end

    let(:description) do
      <<-MARKDNWN.strip_heredoc.strip
      # MergeRequests
      * [ ] !5 Add yes @sue445
      * [ ] !6 Add gogo @sue445
      MARKDNWN
    end

    context "When API v3" do
      let(:api_endpoint) { "http://example.com/api/v3" }

      before do
        stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/merge_requests?iid=5").
          with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
          to_return(status: 200, body: read_stub("merge_requests_with_iid_5.json"), headers: {})

        stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/merge_requests?iid=6").
          with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
          to_return(status: 200, body: read_stub("merge_requests_with_iid_6.json"), headers: {})
      end

      it { should eq description }
    end

    context "When API v4" do
      let(:api_endpoint) { "http://example.com/api/v4" }

      before do
        stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/merge_requests/5").
          with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
          to_return(status: 200, body: read_stub("merge_request_5.json"), headers: {})

        stub_request(:get, "#{api_endpoint}/projects/#{escaped_project_name}/merge_requests/6").
          with(headers: { "Accept" => "application/json", "Private-Token" => private_token }).
          to_return(status: 200, body: read_stub("merge_request_6.json"), headers: {})
      end

      it { should eq description }
    end
  end
end
