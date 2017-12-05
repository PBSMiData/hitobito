# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Role < Person::Filter::Base

  self.permitted_args = [:role_type_ids, :role_types, :kind, :start_at, :finish_at]

  def initialize(attr, args)
    super
    initialize_role_types
  end

  def apply(scope)
    with_deleted(scope).where(type_conditions).where(duration_conditions)
  end

  def blank?
    args[:role_type_ids].blank?
  end

  def to_hash
    merge_duration_args(role_types: args[:role_types])
  end

  def to_params
    merge_duration_args(role_type_ids: args[:role_type_ids].join(ID_URL_SEPARATOR))
  end

  def with_deleted?
    %w(active deleted).include?(args[:kind])
  end

  def time_range
    start_at = args[:start_at].presence || Time.zone.at(0).to_date.to_s
    finish_at = args[:finish_at].presence || Time.zone.now.to_date.to_s

    Date.parse(start_at).beginning_of_day..Date.parse(finish_at).end_of_day
  end

  private

  def merge_duration_args(hash)
    hash.merge(args.slice(:kind, :start_at, :finish_at))
  end

  def initialize_role_types
    classes = role_classes
    args[:role_type_ids] = classes.map(&:id)
    args[:role_types] = classes.map(&:sti_name)
  end

  def role_classes
    if args[:role_types].present?
      role_classes_from_types
    else
      Role.types_by_ids(id_list(:role_type_ids))
    end
  end

  def role_classes_from_types
    map = Role.all_types.each_with_object({}) { |r, h| h[r.sti_name] = r }
    args[:role_types].map { |t| map[t] }.compact
  end

  def with_deleted(scope)
    with_deleted? ? scope.joins(all_roles_join) : scope
  end

  def role_relation
    with_deleted? ? :with_deleted_roles : :roles
  end

  def type_conditions
    [[role_relation, { type: args[:role_types] }]].to_h
  end

  def duration_conditions
    case args[:kind]
    when 'created' then [[role_relation, { created_at: time_range }]].to_h
    when 'deleted' then [[role_relation, { deleted_at: time_range }]].to_h
    when 'active' then [active_role_condition, min: time_range.min, max: time_range.max]
    end
  end

  def active_role_condition
    <<-SQL.strip_heredoc.split.map(&:strip).join(' ')
    with_deleted_roles.created_at <= :max AND
    (with_deleted_roles.deleted_at >= :min OR with_deleted_roles.deleted_at IS NULL)
    SQL
  end

  def all_roles_join
    'INNER JOIN roles AS with_deleted_roles ON with_deleted_roles.person_id = people.id'
  end

end
