const {
  sendMessageSchema,
  createDirectRoomSchema,
  validate,
} = require('../src/utils/validators');

describe('chat validators', () => {
  test('sendMessageSchema accepts valid text payload', () => {
    const validPayload = {
      roomId: '550e8400-e29b-41d4-a716-446655440000',
      content: 'Hello buddy',
      type: 'text',
      mediaUrl: null,
      replyToId: null,
    };

    const { error } = validate(sendMessageSchema, validPayload);
    expect(error).toBeNull();
  });

  test('sendMessageSchema rejects payload with no content and no media', () => {
    const invalidPayload = {
      roomId: '550e8400-e29b-41d4-a716-446655440000',
      content: null,
      type: 'text',
      mediaUrl: null,
      replyToId: null,
    };

    const { error } = validate(sendMessageSchema, invalidPayload);
    expect(error).not.toBeNull();
  });

  test('createDirectRoomSchema requires target_user_id UUID', () => {
    const { error: missing } = validate(createDirectRoomSchema, {});
    expect(missing).not.toBeNull();

    const { error: good } = validate(createDirectRoomSchema, {
      target_user_id: '550e8400-e29b-41d4-a716-446655440000',
    });
    expect(good).toBeNull();
  });
});
