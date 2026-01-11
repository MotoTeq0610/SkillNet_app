# app/models/email.rb
class Email
  include ActiveModel::Model
  include ActiveModel::Attributes

  # JSONの構造(template_email.json)に基づいた属性定義
  attribute :id, :string
  attribute :timestamp, :datetime
  attribute :from_name, :string
  attribute :from_address, :string
  attribute :subject, :string
  attribute :body, :string
  attribute :test_case_id, :string

  # 1. 全てのメール（JSON）を読み込む
  # 使い方: Email.all
  def self.all
    path = Rails.root.join('db', 'data', 'emails', '*.json')
    Dir.glob(path).map do |file|
      load_from_json(file)
    end
  end

  # 2. 特定のIDのメールを探す
  # 使い方: Email.find("msg_nnn")
  def self.find(id)
    all.find { |email| email.id == id }
  end

  # JSONファイルをパースしてEmailオブジェクトに変換する内部メソッド
  def self.load_from_json(file_path)
    json = JSON.parse(File.read(file_path))
    
    new(
      id: json.dig("email", "id"),
      timestamp: json.dig("email", "timestamp"),
      from_name: json.dig("email", "from", "name"),
      from_address: json.dig("email", "from", "address"),
      subject: json.dig("email", "subject"),
      body: json.dig("email", "body"),
      test_case_id: json.dig("metadata", "test_case_id")
    )
  end

  # =====================================================
  # ER図の構想継承：物理DB（ExtReference / Evaluation）との連携
  # =====================================================

  # このメールに対応する DB側の外部参照レコードを取得
  def ext_reference
    # reference_typeが 'Email' かつ external_id がこのオブジェクトのIDと一致するものを検索
    ExtReference.find_by(external_id: self.id, reference_type: 'Email')
  end

  # asset_targets を経由して、最終的な評価結果（Trust-Pスコア等）を取得
  def evaluation
    ext_reference&.asset_target&.evaluation
  end

  # バッジ表示用のヘルパーメソッド（例）
  def trust_p_score
    evaluation&.trust_p_score || 0
  end

  def suspicious?
    evaluation&.is_suspicious || false
  end
end
