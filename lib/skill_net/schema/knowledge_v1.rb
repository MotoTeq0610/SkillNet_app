# frozen_string_literal: true

module SkillNet
  module Schema
    # SkillNet 統合ナレッジ・スキーマ (v1.0)
    # 目的: 相談QAおよび対話型継承から生成されるナレッジの構造を統一し、再利用性を最大化する。
    KNOWLEDGE_MASTER_STRUCTURE = {
      session_summary: {
        category: "String: 技術カテゴリ。大分類/中分類の形式を推奨",
        tech_tags: "Array: 抽象化された技術用語（現象・課題・ドメイン）。最大5個",
        summary: "String: 100-150文字の客観的要約。背景と解決策を網羅する",
        knowledge_fragments: [
          {
            type: "String: 'judgement_logic' (判断の根拠), 'technical_tips' (具体的コツ), 'risk_warning' (失敗予兆)",
            content: "String: 具体的かつ再利用可能な知見の記述"
          }
        ],
        metadata: {
          source_type: "String: 'session' (相談QA) または 'succession' (対話型継承)",
          initial_evaluation: "String: 'None'",
          initial_points: "Integer: 0",
          referenced_history: "Array: 関連する過去の履歴ID（メール、セッション等）"
        }
      }
    }.freeze
  end
end
