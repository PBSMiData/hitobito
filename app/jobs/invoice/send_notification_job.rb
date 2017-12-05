# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::SendNotificationJob < BaseJob

  self.parameters = [:invoice_id, :sender_id, :locale]

  def initialize(invoice, sender)
    super()
    @invoice_id = invoice.id
    @sender_id  = sender.id
  end

  def perform
    set_locale

    pdf_options = { articles: true, esr: false }

    InvoiceMailer.notification(
      invoice.recipient_name,
      invoice.recipient_email,
      sender,
      invoice,
      Export::Pdf::Invoice.render(invoice, pdf_options)
    ).deliver_now
  end

  def invoice
    @invoice ||= Invoice.find(@invoice_id)
  end

  def sender
    @sender ||= Person.find(@sender_id)
  end
end
