import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topicPolicy", "commentPolicy"]
  static values = {
    deleteValue: { type: String, default: "delete" },
    message: { type: String, default: "削除ポリシーが選択されています。過去に退会したユーザーのデータにも遡って適用され、完全に削除されます。この操作は取り消せません。続行しますか？" }
  }

  confirmSubmit(event) {
    if (!this.hasDeletePolicySelected()) {
      return
    }

    if (!confirm(this.messageValue)) {
      event.preventDefault()
    }
  }

  hasDeletePolicySelected() {
    const topicIsDelete = this.hasTopicPolicyTarget &&
      this.topicPolicyTarget.value === this.deleteValueValue
    const commentIsDelete = this.hasCommentPolicyTarget &&
      this.commentPolicyTarget.value === this.deleteValueValue

    return topicIsDelete || commentIsDelete
  }
}
