# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Payment < ActiveRecord::Base

  belongs_to :invoice

  before_validation :set_received_at
  after_create :update_invoice

  scope :list, -> { order(created_at: :desc) }

  validates_by_schema

  def group
    invoice.group
  end

  private

  def update_invoice
    if amount >= invoice.total
      invoice.update(state: :payed)
    end
  end

  def set_received_at
    self.received_at ||= Time.zone.today
  end

end
