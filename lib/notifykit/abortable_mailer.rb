require 'action_mailer'

module AbortableMailer
  class UndeliverableMailMessage < Mail::Message
    def self.deliver
      false
    end

    def self.deliver!
      false
    end
  end

  class AbortDeliveryError < StandardError
  end

  class Base < ActionMailer::Base
    def abort_delivery(reason=nil)
      raise AbortDeliveryError, reason
    end

    def process(*args)
      begin
        super(*args)
      rescue AbortDeliveryError
        self.message = AbortableMailer::UndeliverableMailMessage
      end
    end
  end
end
