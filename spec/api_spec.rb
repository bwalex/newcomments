require 'spec_helper'

describe "API" do
  subject { APP }

  def app
    subject
  end

  context 'get comments' do
    it 'responds with error if the site doesn\'t exist' do
      get '/api/comments', {
        site_domain: 'example.com',
        article_identifier: 'foo'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'site', error_code: "Site not found" }.to_json
    end

    it 'responds with no comments if article doesn\'t exist' do
      site = create(:site)
      get '/api/comments', {
        site_domain: site.domain,
        article_identifier: 'foo'
      }
      last_response.status.should == 200
      last_response.body.should == [].to_json
    end

    it 'responds with all the comments' do
      article = create(:article)
      (1..100).each { |i| create(:comment, article: article) }

      get '/api/comments', {
        site_domain: article.site.domain,
        article_identifier: article.identifier
      }

      last_response.status.should == 200
      last_response.body.should == Comment.all.to_json
    end

    it 'responds with all the comments unless they are not visible' do
      article = create(:article, hidden: true)
      (1..100).each { |i| create(:comment, article: article) }

      get '/api/comments', {
        site_domain: article.site.domain,
        article_identifier: article.identifier
      }

      last_response.status.should == 200
      last_response.body.should == [].to_json
    end

    it 'responds with validation error if site parameter is missing' do
      get '/api/comments', {
        article_identifier: 'moo'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'site_domain is missing' }.to_json
    end

    it 'responds with validation error if article id is missing' do
      get '/api/comments', {
        site_domain: 'example.com'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'article_identifier is missing' }.to_json
    end
  end

  context 'post comment' do
    before do
      @async_mailer = double
      NewCommentEmailJob.stub_chain(:new, :async).and_return @async_mailer
    end

    it 'returns an error if recaptcha verification fails' do
      article = create(:article)

      Recaptcha.should_receive(:verify?).and_return [false, 'Failed miserably']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 403
      last_response.body.should == { error: 'captcha', error_code: 'Failed miserably' }.to_json
      Comment.count.should == 0
    end

    it 'returns an error if recaptcha params are missing' do
      article = create(:article)

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'captcha_response is missing' }.to_json
      Comment.count.should == 0
    end

    it 'returns an error if the site doesn\'t exist' do
      Recaptcha.should_receive(:verify?).and_return [true, '']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: 'example.com',
        article_name: 'Article 1',
        article_url: 'http://www.foo.com/article1',
        article_identifier: 'article-id-1',
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'site', error_code: 'Site not found' }.to_json
      Comment.count.should == 0
    end

    it 'creates the comment and posts an email job if everything is ok' do
      article = create(:article)

      Recaptcha.should_receive(:verify?).and_return [true, '']
      @async_mailer.should_receive(:perform).and_return true

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 201

      Comment.count.should == 1
      Comment.first.email.should == 'foo@bar.com'
      Comment.first.name.should == 'John Doe'
      Comment.first.comment.should == 'Test comment 1'
      Comment.first.article_id.should == article.id
    end

    it 'doesn\'t allow comments if the site is closed for comments' do
      site = create(:site, closed: true)
      article = create(:article, site: site)

      Recaptcha.should_receive(:verify?).and_return [true, '']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 403
      last_response.body.should == { error: 'closed' }.to_json
      Comment.count.should == 0
    end

    it 'doesn\'t allow comments if the article is closed for comments' do
      article = create(:article, closed: true)

      Recaptcha.should_receive(:verify?).and_return [true, '']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 403
      last_response.body.should == { error: 'closed' }.to_json
      Comment.count.should == 0
    end

    it 'creates the article if it doesn\'t exist' do
      site = create(:site)

      Recaptcha.should_receive(:verify?).and_return [true, '']
      @async_mailer.should_receive(:perform).and_return true

      Article.count.should == 0

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: site.domain,
        article_name: 'Fantastic Article 1',
        article_url: 'http://fantastic.com/article',
        article_identifier: 'article-fantastic-1',
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 201

      Article.count.should == 1
      Article.first.name.should == 'Fantastic Article 1'
      Article.first.url.should == 'http://fantastic.com/article'
      Article.first.identifier.should == 'article-fantastic-1'
      Article.first.site_id.should == site.id

      Comment.count.should == 1
      Comment.first.email.should == 'foo@bar.com'
      Comment.first.name.should == 'John Doe'
      Comment.first.comment.should == 'Test comment 1'
      Comment.first.article_id.should == Article.first.id
    end

    it 'doesn\'t create the article if recaptcha fails' do
      site = create(:site)

      Recaptcha.should_receive(:verify?).and_return [false, 'Failed miserably']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: site.domain,
        article_name: 'Fantastic Article 1',
        article_url: 'http://fantastic.com/article',
        article_identifier: 'article-fantastic-1',
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 403
      last_response.body.should == { error: 'captcha', error_code: 'Failed miserably' }.to_json
      Comment.count.should == 0
      Article.count.should == 0
    end

    it 'fails validation if the email is missing' do
      article = create(:article)

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'email is missing' }.to_json
      Comment.count.should == 0
    end

    it 'fails validation if the comment is missing' do
      article = create(:article)

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo@bar.com',
        name: 'John Doe'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'comment is missing' }.to_json
      Comment.count.should == 0
    end

    it 'fails validation if the email is not an email' do
      article = create(:article)

      Recaptcha.should_receive(:verify?).and_return [true, '']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: article.site.domain,
        article_name: article.name,
        article_url: article.url,
        article_identifier: article.identifier,
        email: 'foo.bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'comment', error_code: { email: ['is not an email'] } }.to_json
      Comment.count.should == 0
    end

    it 'fails validation if the article URL is not a URL' do
      site = create(:site)

      Recaptcha.should_receive(:verify?).and_return [true, '']

      post '/api/comments', {
        captcha_challenge: 'challenge1',
        captcha_response: 'response1',
        site_domain: site.domain,
        article_name: 'New Article on Donkeys',
        article_url: 'foobar',
        article_identifier: 'new-article-2',
        email: 'foo@bar.com',
        name: 'John Doe',
        comment: 'Test comment 1'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'article', error_code: { url: ['is invalid'] } }.to_json
      Comment.count.should == 0
    end
  end


  context '/open' do
    it 'responds with cannot comment if comments are closed on the article' do
      article = create(:article, closed: true)

      get '/api/comments/open', {
        site_domain: article.site.domain,
        article_identifier: article.identifier
      }
      last_response.status.should == 200
      last_response.body.should == { can_comment: false }.to_json
    end

    it 'responds with cannot comment if comments are closed on the site' do
      site = create(:site, closed: true)
      article = create(:article, site: site)

      get '/api/comments/open', {
        site_domain: article.site.domain,
        article_identifier: article.identifier
      }
      last_response.status.should == 200
      last_response.body.should == { can_comment: false }.to_json
    end

    it 'responds with error if site doesn\'t exist' do
      get '/api/comments/open', {
        site_domain: 'example.com',
        article_identifier: 'foo'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'Site not found' }.to_json
    end

    it 'responds with cannot comment if article does not exist but site is closed' do
      site = create(:site, closed: true)

      get '/api/comments/open', {
        site_domain: site.domain,
        article_identifier: 'foo'
      }
      last_response.status.should == 200
      last_response.body.should == { can_comment: false }.to_json
    end

    it 'responds with can comment if article does not exist but site is not closed' do
      site = create(:site, closed: false)

      get '/api/comments/open', {
        site_domain: site.domain,
        article_identifier: 'foo'
      }
      last_response.status.should == 200
      last_response.body.should == { can_comment: true }.to_json
    end

    it 'responds with can comment if comments are not closed' do
      article = create(:article)

      get '/api/comments/open', {
        site_domain: article.site.domain,
        article_identifier: article.identifier
      }
      last_response.status.should == 200
      last_response.body.should == { can_comment: true }.to_json
    end

    it 'responds with validation error if site parameter is missing' do
      get '/api/comments/open', {
        article_identifier: 'moo'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'site_domain is missing' }.to_json
    end

    it 'responds with validation error if article id is missing' do
      get '/api/comments/open', {
        site_domain: 'example.com'
      }
      last_response.status.should == 400
      last_response.body.should == { error: 'article_identifier is missing' }.to_json
    end
  end
end
