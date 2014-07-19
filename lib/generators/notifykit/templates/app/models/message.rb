class Message < ActiveRecord::Base

  validates :format, inclusion: %w(text html markdown), allow_blank: true

  def self.default_from
    # TODO
  end

  def self.default_kind
    self.to_s.downcase
  end

  def deliver(user, force=false)
    # Don't send duplicates
    return if self.delivered_to?(user) unless force

    notification = user.notifications.build(
      subject: self,
      kind: kind_or_default,
      category: self.category,
      promotional: self.promotional,
      transactional: self.transactional,
      do_not_track: self.do_not_track,
      deliver_via_site: self.deliver_via_site,
      deliver_via_email: self.deliver_via_email,
      use_default_layout: self.use_default_layout,
      email_from: from_or_default,
      email_reply_to: self.reply_to,
      email_bcc: self.bcc,
      email_subject: self.subject)
    notification.save!
    notification.deliver if notification
    notification
  end

  def deliver_to_all(force=false)
    User.all.each do |user|
      deliver(user, force)
    end
  end

  def delivered_to?(user)
    Notification.where(user_id: user.id, subject_type: self.class.to_s, subject_id: self.id).count > 0
  end

  def formatted_html_body(user=nil)
    content = preprocess(self.html_body, user)
    return '' if content.blank?
    return GitHub::Markup.render('.markdown', content) if defined?(Github::Markup) && self.format && self.format.downcase == 'markdown'
    content
  end

  def formatted_text_body(user=nil)
    content = preprocess(self.text_body, user)
    content
  end

  protected

  def kind_or_default
    result = self.kind
    result = self.class.default_kind if result.blank?
    result
  end

  def from_or_default
    result = self.from
    result = self.class.default_from if result.blank?
    result
  end

  def preprocess(content, user=nil)
    content ||= ""
    content = content.gsub(/\{\{first_name\}\}/, user.first_name) if user.present? && user.first_name.present?
    content = content.gsub(/\{\{last_name\}\}/, user.last_name) if user.present? && user.last_name.present?
    content = content.gsub(/\{\{full_name\}\}/, user.full_name) if user.present? && user.full_name.present?
    content
  end
end
