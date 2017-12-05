# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::PeopleExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:full, :person_filter]

  attr_reader :entries

  def initialize(format, full, user_id, person_filter)
    super()
    @format = format
    @full = full
    @exporter = exporter
    @user_id = user_id
    @tempfile_name = "people-#{format}-zip"
    @person_filter = person_filter
  end

  private

  def send_mail(recipient, file, format)
    Export::PeopleExportMailer.completed(recipient, file, format).deliver_now
  end

  def entries
    entries = @person_filter.entries
    if @full
      full_entries(entries)
    else
      entries.preload_public_accounts.includes(:primary_group)
    end
  end

  def full_entries(entries)
    entries
      .select('people.*')
      .preload_accounts
      .includes(relations_to_tails: :tail, qualifications: { qualification_kind: :translations })
      .includes(:primary_group)
  end

  def exporter
    @full ? Export::Tabular::People::PeopleFull : Export::Tabular::People::PeopleAddress
  end

end
