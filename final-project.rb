#-- List Teachers in an account


require 'typhoeus'
require 'link_header'
require 'json'
require 'csv'

canvas_token = ''
canvas_url = ''
api_endpoint = '/api/v1/accounts/19/courses?include[]=teachers&include[]=total_students&enrollment_term_id=8' # if passing parameters in the URL add a ? followed by parameter # to pass more than one parameter, separate with a & symbol
output_csv = 'C:\Users\rhonda.bauerlein\Dropbox\Canvas\code\ruby\final-project\output.csv'

CSV.open(output_csv, 'wb') do |csv| # Create new file or erase existing file with same name
    csv << ["canvas_course_id", "sis_course_id", "course_code", "teacher_names", "student_count", "published"]
end

request_url = "#{canvas_url}#{api_endpoint}" 
count = 0
page_count = 0
more_data = true
while more_data   # while more_data is true keep looping through the data
    # puts request_url
    page_count += 1
    get_courses = Typhoeus::Request.new(
        request_url,    #we need a variable here because we need the api url to change
        method: :get,
        headers: { authorization: "Bearer #{canvas_token}" }
        )

    get_courses.on_complete do |response|
        #get next link
            links = LinkHeader.parse(response.headers['link']).links
            next_link = links.find { |link| link['rel'] == 'next' } 
            request_url = next_link.href if next_link 
            if next_link && "#{response.body}" != "[]"
                more_data = true
            else
                more_data = false
            end
        #ends next link code

        if response.code == 200
            data = JSON.parse(response.body)
            data.each do |courses| # puts courses
                count += 1
                teacher_names = ""
                # process teachers
                if courses['teachers'] != nil
                    courses['teachers'].each do |course_teachers|
                        if course_teachers['display_name'] != nil
                            teacher_names += "#{course_teachers['display_name']}, "
                        end
                    end
                end
                puts "#{count} - #{courses['id']}, #{courses['sis_course_id']}, #{courses['course_code']}, #{teacher_names}, #{courses['total_students']}, #{courses['workflow_state']}"
                CSV.open(output_csv, 'a') do |csv|
                    csv << [courses['id'], courses['sis_course_id'], courses['course_code'], teacher_names, courses['total_students'], courses['workflow_state']]
                end
            end
        else
            puts "Something went wrong! Response code was #{response.code}"
        end
    end

    get_courses.run
end
puts "Script done running. #{page_count} pages were loaded during the script"
