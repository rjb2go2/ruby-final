#-- List Teachers in an account


require 'typhoeus'
require 'link_header'
require 'json'
require 'csv'

canvas_token = '8940~DsRpPPBDzokxwGimtVo2eWPmM4RWY7J2CC1mZUxdx7Qw5Fo2PgOTSOBINGXewBPX'
canvas_url = 'https://gcccd.test.instructure.com'
api_endpoint = '/api/v1/accounts/19/courses?include[]=teachers&include[]=total_students&enrollment_term_id=8' # if passing parameters in the URL add a ? followed by parameter # to pass more than one parameter, separate with a & symbol
output_csv = 'C:\Users\rhonda.bauerlein\Dropbox\Canvas\code\ruby\final-project\output.csv'

# create the CSV file header row with column headings
  CSV.open(output_csv, 'wb') do |csv| # Create new file or erase existing file with same name
    csv << ["Canvas Course ID", "SIS Course ID", "Teacher", "Student Count", "Published"]
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
            teacher_count = 0
            data.each do |courses| # puts courses
                m_course_id = courses['id']   # reference the course_code field in the array and store as the course_code
                m_sis_course_id = courses['sis_course_id']
                m_published = courses['workflow_state']
                m_total_students = courses['total_students']

                teachers = courses['teachers']
                if teachers != []
              
                    teachers.each do |teachers|
                        m_teacher_name = teachers['display_name']
                        m_teacher_image = teachers['avatar_image_url'] 
                        
                        puts "#{m_course_id}, #{m_sis_course_id}, #{m_teacher_name}, #{m_published}"
                        #write a row to the CSV file
                        CSV.open(output_csv, 'a') do |csv|
                            csv << [m_course_id, m_sis_course_id, m_teacher_name, m_total_students, m_published]
                        end
                    end
                    #puts "#{course_code}"                    # output course codes on one line
                    puts ""
                end
                #Output to the screen what you're putting into the CSV file
                #puts "#{count} - #{courses['id']}, #{courses['sis_course_id']}, #{courses['course_code']}, teacher name #{courses['total_students']}, #{courses['workflow_state']}"
                
               #end
            end
        else
            puts "Something went wrong! Response code was #{response.code}"
        end
    end

    get_courses.run
end
puts "Script done running. #{page_count} pages were loaded during the script"
