const mongoose = require("mongoose");

const NotificationSchema = mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "user",
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: ["TRANSACTION", "CODE", "SYSTEM", "MAINTENANCE"],
      required: true,
    },
    status: {
      type: String,
      enum: ["READ", "UNREAD"],
      default: "UNREAD",
    },
    amount: {
      type: Number,
      default: null,
    },
    code: {
      type: String,
      default: null,
    },
    codeStatus: {
      type: String,
      enum: ["GENERATED", "ACTIVE", "USED", "EXPIRED", "CANCELED"],
      default: null,
    },
    codeExpiryTime: {
      type: Date,
      default: null,
    },
    vendingMachineId: {
      type: String,
      default: null,
    },
    deviceInfo: {
      type: String,
      default: null,
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "order",
      default: null,
    },
    products: [
      {
        productId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "product",
        },
        quantity: {
          type: Number,
        },
        price: {
          type: Number,
        },
      },
    ],
    priority: {
      type: Number,
      min: 1,
      max: 5,
      default: 3, // Medium priority
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
NotificationSchema.index({ userId: 1, status: 1, createdAt: -1 });
NotificationSchema.index({ type: 1, createdAt: -1 });
NotificationSchema.index({ vendingMachineId: 1, createdAt: -1 });

module.exports = mongoose.model("notification", NotificationSchema);