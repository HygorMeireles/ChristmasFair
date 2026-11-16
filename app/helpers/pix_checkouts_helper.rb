module PixCheckoutsHelper
  def pix_qr_svg(data)
    return if data.blank?

    RQRCode::QRCode.new(data).as_svg(
      color: "000",
      module_size: 4,
      standalone: true,
      use_path: true,
      viewbox: true
    ).html_safe
  end
end
