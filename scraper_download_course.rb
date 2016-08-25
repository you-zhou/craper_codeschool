require 'nokogiri'
require 'watir-webdriver'
require 'open-uri'
require 'open_uri_redirections'

Selenium::WebDriver::Firefox::Binary.path='C:\Users\jack.zhou\AppData\Local\Mozilla Firefox\firefox.exe'

class CodeSchoolDownloader
  attr_accessor :browser
  DOWNLOAD_LOCATION = Dir.home + '/Desktop/CodeschoolRetry'
  TIMEOUT = 0

  def initialize username, password
    @browser = Watir::Browser.new
    login username, password
    create_dir DOWNLOAD_LOCATION
    download_courses
  end

  def login username, password
    @browser.goto 'https://www.codeschool.com/users/sign_in'

    t = @browser.text_field :id => 'user_login'
    t.set username

    t = @browser.text_field :id => 'user_password'
    t.set password

    @browser.button(class: 'form-btn').click
  end

  def download_courses
    dir_name = DOWNLOAD_LOCATION + '/courses'
    create_dir dir_name
    # Specified course URLs.
    # e.g. "https://www.codeschool.com/courses/rails-testing-for-zombies/videos"
    course_urls = []
    course_urls.each do |url|
      download url, dir_name
    end
  end

  def download url, dir_name, passed_in_filename = nil
    puts "\nCourse"
    p url
    puts

    @browser.goto url
    html = @browser.html
    page = Nokogiri::HTML.parse(html)
    sub_dir_name =  dir_name + '/' + page.css('h1').text.gsub('Screencast', '').strip.gsub(/\W/, ' ').gsub(/\s+/, ' ').gsub(/\s/, '-')
    create_dir sub_dir_name
    filenames = page.css('.tct').map(&:text)
    counter = 0
    links = @browser.links(:class, "js-level-open")
    videos_total = links.size
    links.each do |course|
      begin
        puts "Opening video..."
        if videos_total - counter - 1 == 0
          puts "This is the last lesson from this course"
        else
          puts "Videos left #{(videos_total - counter - 1).to_s}"
        end
        course.when_present.fire_event("click")
        sleep 1
        video_page = Nokogiri::HTML.parse(@browser.html)
        url = video_page.css('div#level-video-player video').attribute('src').value
        puts "URL retrieved"
        puts "Closing video..."
        @browser.links(:class, "modal-close")[3].when_present.fire_event("click")
        name = passed_in_filename ? passed_in_filename : "#{(counter + 1).to_s.ljust 2}- #{filenames[counter]}"
        filename = "#{sub_dir_name}/#{name}.mp4"
        File.open(filename, 'wb') do |f|
          puts "Downloading video #{name}..."
          f.write(open(url, allow_redirections: :all).read)
          puts "Saving #{filename}..."
        end
      rescue => e
        p e.inspect
      end
      counter += 1
    end
  end

  def create_dir filename
    unless File.exist? filename
      FileUtils.mkdir filename
    end
  end

  def timeout
    TIMEOUT + rand(5)
  end
end


CodeSchoolDownloader.new(*ARGV)