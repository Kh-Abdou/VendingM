const mongoose = require("mongoose");

const OrderSchema = mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "user",
      required: true,
    },
    products: [
      {
        productId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "product",
          required: true,
        },
        quantity: {
          type: Number,
          required: true,
          min: 1,
        },
        price: {
          type: Number,
          required: true,
        },
      },
    ],
    totalAmount: {
      type: Number,
      required: true,
    },
    paymentMethod: {
      type: String,
      enum: ["EWALLET", "CODE"],
      required: true,
    },    status: {
      type: String,
      enum: ["PENDING", "COMPLETED", "CANCELED", "FAILED"],
      default: "PENDING",
    },
    isDispensingInProgress: {
      type: Boolean,
      default: false,
    },
    code: {
      type: String,
      default: null,
    },
    codeExpiryTime: {
      type: Date,
      default: null,
    },
    codeStatus: {
      type: String,
      enum: ["ACTIVE", "USED", "EXPIRED", "CANCELED"],
      default: null,
    },
    vendingMachineId: {
      type: String,
      default: null,
    },
    dispensedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("order", OrderSchema);