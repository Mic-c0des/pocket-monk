import SwiftUI

struct AddFriendView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FriendsViewModel
    @State private var method: AddFriendMethod = .username
    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    init(viewModel: FriendsViewModel) {
        self.viewModel = viewModel
    }

    private var validationMessage: String? {
        input.isEmpty ? nil : method.validationMessage(for: input)
    }

    private var canSubmit: Bool {
        !input.isEmpty && validationMessage == nil && !viewModel.isAddingFriend
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                    Picker("Add by", selection: $method) {
                        ForEach(AddFriendMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                        Text(method.prompt)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        TextField(method.placeholder, text: $input)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(method == .inviteLink ? .URL : .asciiCapable)
                            .submitLabel(.send)
                            .focused($isInputFocused)
                            .onSubmit(submit)
                            .padding(PocketMonkSpacing.medium)
                            .background(
                                PocketMonkColors.surface.color(for: colorScheme),
                                in: RoundedRectangle(cornerRadius: PocketMonkCornerRadius.small)
                            )

                        if let message = viewModel.addFriendErrorMessage ?? validationMessage {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                        }
                    }

                    PocketMonkButton(
                        title: method.actionTitle,
                        systemImage: method.actionSystemImage,
                        action: submit
                    )
                    .disabled(!canSubmit)

                    if viewModel.isAddingFriend {
                        HStack(spacing: PocketMonkSpacing.small) {
                            ProgressView()
                            Text("Reaching out…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    Text(SampleFriendsData.tryItHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(PocketMonkSpacing.large)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(PocketMonkColors.canvas.color(for: colorScheme))
            .navigationTitle("Add a friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.clearAddFriendError()
            isInputFocused = true
        }
        .onChange(of: method) {
            input = ""
            viewModel.clearAddFriendError()
        }
        .onChange(of: input) {
            viewModel.clearAddFriendError()
        }
    }

    private func submit() {
        guard canSubmit else { return }
        Task {
            if await viewModel.addFriend(input, method: method) {
                dismiss()
            }
        }
    }
}

#Preview {
    AddFriendView(
        viewModel: FriendsViewModel(service: LocalFriendsService(store: InMemoryFriendshipStore()))
    )
}
