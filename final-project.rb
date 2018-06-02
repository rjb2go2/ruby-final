#-- List Teachers in an account

require 'typhoeus'
require 'link_header'
require 'json'
require 'csv'

# Initialize variables
canvas_token = '8940~yTRUoszOamzEDaKMd5Xu70WBrv1xlBvxfA5vMCtDYgupa1Y8pK4vJMUDGyaehekB'
canvas_url = 'https://gcccd.instructure.com'
api_endpoint = '/api/v1/accounts/4/courses?include[]=teachers&include[]=total_students&enrollment_term_id=8' # if passing parameters in the URL add a ? followed by parameter # to pass more than one parameter, separate with a & symbol
request_url = "#{canvas_url}#{api_endpoint}" 
course_count = 0
teacher_count = 0
more_data = true
output_csv = ENV['HOME']+'\Dropbox\Canvas\code\ruby\final-project\output.csv'

# create the CSV file and write the header row with column headings
CSV.open(output_csv, 'wb') do |csv| # Create new file or erase existing file with same name
    csv << ["Course ID", "Course Code", "Teacher", "Avatar", "Published"]
end

# process the API request (request_url) result in pages of 10 records of json data until all data has been processed
while more_data

    # send the API request for a page of data
    get_courses = Typhoeus::Request.new(
        request_url,
        method: :get,
        headers: { authorization: "Bearer #{canvas_token}" }
        )

    get_courses.on_complete do |response|
        
        # read the page header data and find the next page number
        links = LinkHeader.parse(response.headers['link']).links
        next_link = links.find { |link| link['rel'] == 'next' }
        
        # append the next page text to the request_url
        request_url = next_link.href if next_link 
        
        if next_link && "#{response.body}" != "[]"
            more_data = true
        else
            more_data = false
        end

        if response.code == 200
            data = JSON.parse(response.body)
            data.each do |courses| # puts courses
                course_count += 1
                teachers = courses['teachers']
                if teachers != []
                    teachers.each do |teachers|
                        teacher_count += 1
                        puts "#{courses['id']}, #{courses['course_code']}, #{teachers['display_name']}"
                        #write a row to the CSV file
                        CSV.open(output_csv, 'a') do |csv|
                            csv << [courses['id'], courses['course_code'], teachers['display_name'], teachers['avatar_image_url'], courses['workflow_state']]
                        end
                    end

                    # add blank line between courses
                    puts ""
                end
            end
        else
            puts "Something went wrong! Response code was #{response.code}"
        end
    end
    puts ""
    get_courses.run
end
puts "Script done running."
puts "#{course_count} courses and #{teacher_count} teachers were processed"
puts ""
