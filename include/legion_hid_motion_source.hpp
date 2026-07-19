#pragma once

#include "legion_hid_protocol.hpp"
#include "motion_source.hpp"

#include <cstdint>

namespace motion
{
class LegionHIDMotionSource final : public MotionSource
{
  public:
    LegionHIDMotionSource() = default;
    ~LegionHIDMotionSource() override;

    LegionHIDMotionSource(const LegionHIDMotionSource&) = delete;
    auto operator=(const LegionHIDMotionSource&)
        -> LegionHIDMotionSource& = delete;

    bool initialize() override;
    bool poll(MotionSample& sample) override;

  private:
    void close_device();
    bool reconnect();
    bool send_initialization_packets();

    int fd_ = -1;
    bool have_timestamp_ = false;
    std::uint8_t previous_timestamp_ = 0;
    legion_protocol::ControllerSide selected_side_ =
        legion_protocol::ControllerSide::Right;
};
} // namespace motion
