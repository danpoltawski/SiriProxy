require 'tweaksiri'
require 'siriobjectgenerator'

class Moodle < SiriPlugin

    ####
    # This gets called every time an object is received from the Guzzoni server
    def object_from_guzzoni(object, connection) 

        object
    end

    ####
    # This gets called every time an object is received from an iPhone
    def object_from_client(object, connection)

        object
    end

    def get_search_results(search, connection)
        if(search.match("integration"))
            url = "http://tracker.moodle.org/rest/api/2.0.alpha1/search?jql=project+%3D+MDL+AND+%28%22Currently+in+integration%22+is+not+empty+OR+status+in+%28%22Integration+review+in+progress%22%2C+%22Waiting+for+testing%22%2C+%22Testing+in+progress%22%2C+%22Problem+during+testing%22%2C+Tested%29%29&startAt=0&%20maxResults=100"
        else
            url = "http://tracker.moodle.org/rest/api/2.0.alpha1/search?jql=parent++%3D+MDLQA-1190+and+status+%3D+'open'"
        end

        Thread.new {
            status = JSON.parse(open(url).read)

            total = status["total"]


            txt = "There are currently #{total} issues #{search}"

            connection.inject_object_to_output_stream(generate_siri_utterance(connection.lastRefId, txt))
        }                               
        return "Searching the Moodle tracker.."
    end                                     


    def get_bug_details(bugid, connection)
        Thread.new {
            status = JSON.parse(open("http://tracker.moodle.org/rest/api/2.0.alpha1/issue/#{bugid}").read)
            summary = status["fields"]["summary"]["value"]
            assignee = status["fields"]["assignee"]["value"]["displayName"]
            reporter = status["fields"]["reporter"]["value"]["displayName"]
            status = status["fields"]["status"]["value"]["name"]

            if (status.match(/open/))
                status = "open, go fix it!"
            end

            txt = "Issue #{bugid} is currently assigned to #{assignee}. It was reported by #{reporter}. The summary is '#{summary}'. The issue is #{status}"

            connection.inject_object_to_output_stream(generate_siri_utterance(connection.lastRefId, txt))
        }	
        return "One moment while I lookup #{bugid} in the Moodle tracker"
    end

    ####
    # When the server reports an "unkown command", this gets called. It's useful for implementing commands that aren't otherwise covered
    def unknown_command(object, connection, command)
        object
    end

    ####
    # This is called whenever the server recognizes speech. It's useful for overriding commands that Siri would otherwise recognize
    def speech_recognized(object, connection, phrase)
        if(phrase.match(/What should I do today/i))
            self.plugin_manager.block_rest_of_session_from_server

            return generate_siri_utterance(connection.lastRefId, "Work on Moodle 2.2 Quality Assurance Testing")
        end

        if(phrase.match(/integration/i))
            self.plugin_manager.block_rest_of_session_from_server		
            response = get_search_results("in integration", connection)
            connection.inject_object_to_output_stream(generate_siri_utterance(connection.lastRefId, response))
        end

        if(phrase.match(/need testing/i))
            self.plugin_manager.block_rest_of_session_from_server		
            response = get_search_results("which need testing", connection)
            connection.inject_object_to_output_stream(generate_siri_utterance(connection.lastRefId, response))
        end

        if(phrase.match(/issue/i))
            if(bugid = phrase.match(/([0-9]+)/)[1] rescue false)
                self.plugin_manager.block_rest_of_session_from_server		
                if (phrase.match(/quality/i))
                    bug = "QA-#{bugid}"
                else
                    bug = "MDL-#{bugid}"
                end

                response = get_bug_details(bug, connection)
                connection.inject_object_to_output_stream(generate_siri_utterance(connection.lastRefId, response))
            end
        end



        object
        end

    end 
