# app/services/email_analyzer.rb（修正・統合案）

class EmailAnalyzer
  def self.call(email)
    new(email).analyze
  end

  def initialize(email)
    @email = email
    # @client = Gemini.new ... は Gem が必要なため削除し、
    # 既に作成済みの GeminiClient を使用します
  end

  def analyze
    # 1. 過去の評価事例をリファレンスとして取得（ここはDBを利用）
    references = Evaluation.where('trust_p_score >= ?', 4.0).limit(5).map do |ev|
      "事例: #{ev.details['ai_reason']} (スコア: #{ev.trust_p_score})"
    end.join("\n")

    # 2. プロンプトの組み立て（@email は DB ではなく Email クラスのインスタンス）
    prompt = build_prompt(references)
    
    # 3. GeminiClient (Gemなし版) を呼び出して解析
    # ここで「Gemfileを汚さないロジック」との合流です
    raw_response = GeminiClient.generate(prompt)

    # 4. JSONのパースと保存
    # AIの返答からJSON部分のみを抽出（Markdownのコードブロック対策）
    json_content = raw_response.match(/\{.*\}/m).to_s
    parsed_data = JSON.parse(json_content)

    save_to_db(parsed_data)
  rescue => e
    "Analysis Error: #{e.message}"
  end

  private

  def build_prompt(references)
    # 共有いただいたプロンプトを活用
    <<~PROMPT
      あなたはセキュリティエンジニアです。
      以下の「ユーザーから高く評価された過去の事例」を参考にしつつ、新しいメールを分析してください。

      【参考にする高評価事例】
      #{references}

      【分析対象のメール】
      送信者: #{@email.from_name} <#{@email.from_address}>
      件名: #{@email.subject}
      本文: #{@email.body}

      【出力JSON形式】（これ以外は出力しないでください）
      {
        "is_suspicious": 不審ならtrue,
        "reason": "判定の根拠（100文字以内）",
        "badges": ["タグ1", "タグ2"]
      }
    PROMPT
  end

  def save_to_db(data)
    ActiveRecord::Base.transaction do
      # @email.id を使って AssetTarget を特定
      target = AssetTarget.find_or_create_by!(name: "Email:#{@email.id}")
      
      evaluation = Evaluation.find_or_initialize_by(asset_target: target)
      evaluation.update!(
        is_suspicious: data["is_suspicious"],
        details: (evaluation.details || {}).merge({
          ai_reason: data["reason"],
          badges: data["badges"]
        })
      )
    end
  end
end
