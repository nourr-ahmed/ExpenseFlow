module Api
  module V1
    class TeamsController < ApplicationController
      before_action :set_team, only: [:show, :update]

      def index
        authorize Team, :index?
        teams = policy_scope(Team)
        render json: teams.map { |t| TeamSerializer.new(t).as_json }
      end

      def show
        authorize @team
        render json: TeamSerializer.new(@team).as_json
      end

      def create
        @team = Team.new(team_params)
        authorize @team
        @team.save!
        render json: TeamSerializer.new(@team).as_json, status: :created
      end

      def update
        authorize @team
        @team.update!(team_params)
        render json: TeamSerializer.new(@team).as_json
      end

      private

      def set_team
        @team = Team.find(params[:id])
      end

      def team_params
        params.require(:team).permit(:name, :manager_id)
      end
    end
  end
end