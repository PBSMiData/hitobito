# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe InvoicesController do

  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  context 'authorization' do
    before { sign_in(person) }

    it "may index when person has finance permission on layer group" do
      get :index, group_id: group.id
      expect(response).to be_success
    end

    it "may edit when person has finance permission on layer group" do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      get :edit, group_id: group.id, id: invoice.id
      expect(response).to be_success
    end

    it "may not index when person has no finance permission on layer group" do
      expect do
        get :index, group_id: groups(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has no finance permission on layer group" do
      invoice = Invoice.create!(group: groups(:top_layer), title: 'test', recipient: person)
      expect do
        get :edit, group_id: groups(:top_layer).id, id: invoice.id
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'searching' do
    let(:invoice) { invoices(:invoice) }
    before        { sign_in(person) }

    it 'GET#index finds invoices by title' do
      get :index, group_id: group.id, q: 'Invoice'
      expect(assigns(:invoices)).to have(1).item
    end

    it 'GET#index finds invoices by sequence_number' do
      get :index, group_id: group.id, q: invoices(:invoice).sequence_number
      expect(assigns(:invoices)).to have(1).item
    end

    it 'GET#index finds invoices by recipient.last_name' do
      get :index, group_id: group.id, q: people(:top_leader).last_name
      expect(assigns(:invoices)).to have(2).item
    end

    it 'GET#index finds nothing for dummy' do
      get :index, group_id: group.id, q: 'dummy'
      expect(assigns(:invoices)).to be_empty
    end

    it 'filters invoices by state' do
      get :index, group_id: group.id, state: :draft
      expect(assigns(:invoices)).to have(1).item
    end

    it 'filters invoices by due_since' do
      invoice.update(due_at: 2.weeks.ago)
      get :index, group_id: group.id, due_since: :one_week
      expect(assigns(:invoices)).to have(1).item
    end
  end

  context 'show' do
    let(:invoice) { invoices(:invoice) }
    before { sign_in(person) }

    it 'GET#show assigns reminder if invoice has been sent' do
      invoice.update(state: :sent)
      get :show, group_id: group.id, id: invoice.id
      expect(assigns(:reminder)).to be_present
      expect(assigns(:reminder_valid)).to eq true
    end

    it 'GET#show assigns payment if invoice has been sent' do
      invoice.update(state: :sent)
      get :show, group_id: group.id, id: invoice.id
      expect(assigns(:payment)).to be_present
      expect(assigns(:payment_valid)).to eq true
      expect(assigns(:payment).amount).to eq 5
    end

    it 'GET#show assigns payment with amount_open' do
      invoice.update(state: :sent)
      invoice.payments.create!(amount: 0.5)
      get :show, group_id: group.id, id: invoice.id
      expect(assigns(:payment)).to be_present
      expect(assigns(:payment_valid)).to eq true
      expect(assigns(:payment).amount).to eq 4.5
    end

    it 'GET#show assigns reminder with flash parameters' do
      invoice.update(state: :sent)
      allow(subject).to receive(:flash).and_return(payment_reminder: { due_at: invoice.due_at })
      get :show, group_id: group.id, id: invoice.id
      expect(assigns(:reminder)).to be_present
      expect(assigns(:reminder_valid)).to eq false
    end

    it 'GET#show assigns payment with flash parameters' do
      invoice.update(state: :sent)
      allow(subject).to receive(:flash).and_return(payment: {})
      get :show, group_id: group.id, id: invoice.id
      expect(assigns(:payment)).to be_present
      expect(assigns(:payment_valid)).to eq false
    end

    it 'exports pdf' do
      get :show, group_id: group.id, id: invoice.id, format: :pdf

      expect(response.header['Content-Disposition']).to match(/Rechnung-#{invoice.sequence_number}.pdf/)
      expect(response.content_type).to eq('application/pdf')
    end

    it 'exports csv' do
      get :show, group_id: group.id, id: invoice.id, format: :csv

      expect(response.header['Content-Disposition']).to match(/Rechnung-#{invoice.sequence_number}.csv/)
      expect(response.content_type).to eq('text/csv')
    end
  end

  it 'DELETE#destroy moves invoice to cancelled state' do
    sign_in(person)

    invoice = Invoice.create!(group: group, title: 'test', recipient: person)
    expect do
      delete :destroy, group_id: group.id, id: invoice.id
    end.not_to change { group.invoices.count }
    expect(invoice.reload.state).to eq 'cancelled'
    expect(response).to redirect_to group_invoices_path(group)
    expect(flash[:notice]).to eq 'Rechnung wurde storniert.'
  end

  context '#index' do
    before { sign_in(person) }

    it 'exports pdf' do
      get :index, group_id: group.id, format: :pdf
      expect(response.header['Content-Disposition']).to match(/rechnungen.pdf/)
      expect(response.content_type).to eq('application/pdf')
    end

    it 'exports labels pdf' do
      get :index, group_id: group.id, label_format_id: label_formats(:standard).id, format: :pdf
      expect(response.content_type).to eq('application/pdf')
    end

    it 'exports pdf' do
      get :index, group_id: group.id, format: :csv
      expect(response.header['Content-Disposition']).to match(/rechnungen.csv/)
      expect(response.content_type).to eq('text/csv')
    end
  end

end
